import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, QueryCommand } from "@aws-sdk/lib-dynamodb";

const DYNAMO_TABLE = "FocusHub_Tasks";
const dbClient = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(dbClient);

export const handler = async (event) => {
  try {
    // Usaremos un userId fijo por ahora
    const userId = "demo_user"; 

    const command = new QueryCommand({
      TableName: DYNAMO_TABLE,
      KeyConditionExpression: "userId = :uid",
      ExpressionAttributeValues: {
        ":uid": userId,
      },
    });

    const data = await ddbDocClient.send(command);

    return {
      statusCode: 200,
      headers: { "Access-Control-Allow-Origin": "*" }, // CORS
      body: JSON.stringify(data.Items),
    };
  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};