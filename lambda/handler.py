import boto3
import json
import uuid
import datetime
import os
import logging
from botocore.exceptions import ClientError
import re


logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3 = boto3.client('s3')
bedrock = boto3.client("bedrock-runtime")

S3_BUCKET = os.environ.get('S3_BUCKET')

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
    try:
        logger.info("Incoming event: %s", json.dumps(event))
        body = json.loads(event.get("body", "{}"))
        code = body.get("code")
    
        if not code:
            raise ValueError("Code is required in the request body")
        
        prompt = (
            f"\n\nHuman: Is this code plagiarized or AI-generated?\n\n"
            f"{code}\n\n"
            f"Explain and give a confidence score (0-100).\n\nAssistant:"
        )

        response = bedrock.invoke_model(
            modelId="anthropic.claude-v2",
            contentType="application/json",
            accept="application/json",
            body=json.dumps({
                "prompt": prompt,
                "max_tokens_to_sample": 300,
                "stop_sequences": ["\n\nHuman:"],
                "temperature": 0.5
            })
        )

        model_response = json.loads(response['body'].read().decode())

        file_key = f"results/{datetime.datetime.utcnow().isoformat()}_{uuid.uuid4().hex}.json"

        s3.put_object(
            Bucket=S3_BUCKET,
            Key=file_key,
            Body=json.dumps({"input_code": code, "analysis_result": model_response}),
            ContentType='application/json'
        )

        logger.info("Result stored at S3 key: %s", file_key)

        parsed = parse_response(model_response.get("completion", ""))

        return {
            "statusCode": 200,
            "body": json.dumps({ 
                "result": parsed, 
                "s3_key": file_key 
            })
        }
    
    except ValueError as ve:
        logger.error("Input validation error: %s", str(ve))
        return {
            "statusCode": 400,
            "body": json.dumps({"error": str(ve)})
        }
    
    except ClientError as e:
        logger.error("AWS ClientError: %s", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Internal server error"})
        }
    
    except Exception as e:
        logger.error("Unexpected error: %s", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Internal server error"})
        }

    