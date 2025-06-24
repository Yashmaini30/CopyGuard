import boto3
import json
import uuid
import datetime
import os

s3 = boto3.client('s3')
bedrock = boto3.client("bedrock-runtime")

S3_BUCKET = os.environ.get('S3_BUCKET')

def lambda_handler(event, context):
    body = json.loads(event['body'])
    code = body.get("code")

    prompt = f"Human: Is this code plagiarized or AI-generated?\n\n{code}\n\nExplain and give a confidence score (0-100).\n\nAssistant:"

    client = boto3.client("bedrock-runtime")
    response = client.invoke_model(
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
        Body=json.dumps({
            "input_code": code,
            "analysis_result": model_response
        }),
        ContentType='application/json'
    )
    return {
        "statusCode": 200,
        "body": json.dumps({ "result": model_response })
    }