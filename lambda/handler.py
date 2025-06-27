import boto3
import json
import uuid
import datetime
import os
import logging
from botocore.exceptions import ClientError
import re
import time


logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client('s3')
bedrock = boto3.client("bedrock-runtime")
cloudwatch = boto3.client('cloudwatch')

S3_BUCKET = os.environ.get('S3_BUCKET')
METRIC_NAMESPACE = os.environ.get('METRIC_NS','CodeDetector')
EXPECTED_API_KEY = os.environ.get('EXPECTED_API_KEY')

def parse_response(text):
    confidence_score = None
    label = None

    confidence_patterns = [
        r"confidence\s*(?:score|level)?\s*(?:of|is|:)?\s*(\d{1,3})\s*(?:%|percent)?",
        r"(\d{1,3})\s*(?:%|percent)\s*confidence",
        r"score\s*(?:of|is|:)?\s*(\d{1,3})\s*(?:%|percent)?",
        r"(\d{1,3})\s*(?:%|percent)\s*(?:certain|sure|confident)",
        r"estimate\s*(?:of|is|:)?\s*(\d{1,3})\s*(?:%|percent)?"
    ]
    
    for pattern in confidence_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            try:
                confidence_score = int(match.group(1))
                if 0 <= confidence_score <= 100:  
                    break
            except (IndexError, ValueError):
                continue

    text_lower = text.lower()
    
    negation_patterns = [
        r"not\s+ai[- ]generated",
        r"not\s+generated\s+by\s+ai",
        r"not\s+from\s+(?:an?\s+)?ai",
        r"doesn't\s+appear\s+to\s+be\s+ai",
        r"unlikely\s+to\s+be\s+ai",
        r"probably\s+not\s+ai"
    ]
    
    ai_patterns = [
        r"ai[- ]generated",
        r"generated\s+by\s+(?:an?\s+)?ai",
        r"(?:appears|seems|looks)\s+to\s+be\s+ai[- ]generated",
        r"likely\s+ai[- ]generated",
        r"probably\s+ai[- ]generated",
        r"language\s+model\s+generated",
        r"machine\s+generated",
        r"artificial\s+intelligence",
        r"ai\s+system",
        r"generated\s+by.*ai",
        r"confident.*ai",
        r"suggests.*ai",
        r"characteristic\s+of\s+ai",
        r"hallmarks\s+of\s+ai"
    ]

    human_patterns = [
        r"human[- ]written",
        r"written\s+by\s+(?:a\s+)?human",
        r"(?:appears|seems|looks)\s+to\s+be\s+human[- ]written",
        r"likely\s+human[- ]written",
        r"probably\s+human[- ]written",
        r"human\s+(?:code|author|programmer)"
    ]
    
    if any(re.search(pattern, text_lower) for pattern in negation_patterns):
        label = "Human-written"
    elif any(re.search(pattern, text_lower) for pattern in human_patterns):
        label = "Human-written"
    elif any(re.search(pattern, text_lower) for pattern in ai_patterns):
        label = "AI-generated"
    else:
        decision_phrases = [
            r"confident.*(?:this|code).*(?:was|is).*ai",
            r"confident.*ai.*generated",
            r"suggests.*ai.*generation",
            r"confident.*(?:this|code).*(?:was|is).*human",
            r"confident.*human.*(?:wrote|written)",
            r"suggests.*human.*(?:wrote|written)"
        ]
        
        for phrase in decision_phrases:
            if re.search(phrase, text_lower):
                if 'ai' in phrase:
                    label = "AI-generated"
                else:
                    label = "Human-written"
                break
        else:
            if re.search(r"overall.*confident.*ai", text_lower):
                label = "AI-generated"
            elif re.search(r"overall.*confident.*human", text_lower):
                label = "Human-written"
            else:
                label = "Unknown"
    
    return {
        "label": label,
        "confidence": confidence_score,
        "raw": text
    }

def lambda_handler(event, context):

    headers = {k.lower(): v for k, v in (event.get("headers") or {}).items()}
    if headers.get("x-api-key") != EXPECTED_API_KEY:
        logger.warning("Unauthorized: missing/invalid X-API-Key")
        return {"statusCode": 403, "body": json.dumps({"error": "Forbidden"})}
    
    start = time.time()
    try:
        logger.info("Incoming event: %s", json.dumps(event))
        body = json.loads(event.get("body", "{}"))
        code = body.get("code")
        if not code:
            raise ValueError("Code is required in the request body")

        prompt = (
            "\n\nHuman: Is this code plagiarized or AI-generated?\n\n"
            f"{code}\n\n"
            "Explain and give a confidence score (0-100).\n\nAssistant:"
        )

        resp = bedrock.invoke_model(
            modelId="anthropic.claude-v2",
            contentType="application/json",
            accept="application/json",
            body=json.dumps(
                {
                    "prompt": prompt,
                    "max_tokens_to_sample": 300,
                    "stop_sequences": ["\n\nHuman:"],
                    "temperature": 0.5,
                }
            ),
        )
        model_resp = json.loads(resp["body"].read().decode())
        parsed = parse_response(model_resp.get("completion", ""))

        file_key = (
            f"results/{datetime.datetime.utcnow().isoformat()}_{uuid.uuid4().hex}.json"
        )
        s3.put_object(
            Bucket=S3_BUCKET,
            Key=file_key,
            Body=json.dumps(
                {
                    "timestamp": datetime.datetime.utcnow().isoformat(),
                    "input_code": code,
                    "parsed_result": parsed,
                    "raw_response": model_resp,
                }
            ),
            ContentType="application/json",
        )
        logger.info("Result stored at S3 key: %s", file_key)

       
        try:
            cloudwatch.put_metric_data(
                Namespace=METRIC_NAMESPACE,
                MetricData=[
                    {
                        "MetricName": "ConfidenceScore",
                        "Value": float(parsed["confidence"] or 0),
                        "Unit": "Percent",
                    },
                    {
                        "MetricName": "IsAIGenerated",
                        "Value": 1 if parsed["label"] == "AI-generated" else 0,
                        "Unit": "Count",
                    },
                    {
                        "MetricName": "LatencyMs",
                        "Value": round((time.time() - start) * 1000, 2),
                        "Unit": "Milliseconds",
                    },
                ],
            )
        except ClientError as cw_err:
            logger.warning("PutMetricData failed: %s", cw_err)

       
        return {
            "statusCode": 200,
            "body": json.dumps({"result": parsed, "s3_key": file_key}),
        }

    except ValueError as ve:
        logger.error("Bad request: %s", ve)
        return {"statusCode": 400, "body": json.dumps({"error": str(ve)})}
    except Exception as e:
        logger.error("Unhandled error", exc_info=True)
        return {"statusCode": 500, "body": json.dumps({"error": "Internal error"})}