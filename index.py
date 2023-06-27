# Libraries added for AWS, json, and time
import boto3

# variables for attaching the dynamodb table
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Visitor-Counter')

# Func for counting the amount of times this code is executed in lambda (oc=overall count)
def lambda_handler(event, context):
    response = table.update_item(
        Key={
            "Countname" : "visitor_count"
        },
        UpdateExpression='ADD #c :increment',
        ExpressionAttributeNames={
            "#c": "count"
        },
        ExpressionAttributeValues={
            ':increment': 1
        },
        ReturnValues='UPDATED_NEW'
    )

    # global counter
    counter = response['Attributes']['count']
    data = {'counter': int(counter)}
    
    return {
        "statusCode": 200,
        "body": data,
    "headers": {
            "Access-Control-Allow-Origin": "https://www.ravenspencer.com",
            "Access-Control-Allow-Headers": "Content-Type, X-Amz-Date,Authorization, X-Api-Key, X-Amz-Security-Token",
            "Access-Control-Allow-Methods": "OPTIONS,POST,GET",
            "Content-Type": "application/json"
        }
}