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

def parse_response(text):
    confidence_score = None
    label = None

    match = re.search(
        r"(?:estimate|confidence(?: score)?(?: of)?)\D{0,10}(\d{1,3})\s*(?:%|percent)?",
        text,
        re.IGNORECASE
    )

    if match:
        try:
            confidence_score = int(match.group(1))
        except (IndexError, ValueError):
            confidence_score = None 

    if "AI-generated" in text or "language model" in text:
        label = "AI-generated"
    elif "written by a human" in text or "not AI-generated" in text:
        label = "Human-written"
    else:
        label = "Unknown"

    return {
        "label": label,
        "confidence": confidence_score,
        "raw": text
    }


def lambda_handler(event, context):
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