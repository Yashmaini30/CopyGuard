import boto3
import json

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
    return {
        "statusCode": 200,
        "body": json.dumps({ "result": model_response })
    }