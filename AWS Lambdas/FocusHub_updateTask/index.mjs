import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, UpdateCommand } from "@aws-sdk/lib-dynamodb";

const DYNAMO_TABLE = "FocusHub_Tasks";
const dbClient = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(dbClient);

export const handler = async (event) => {
  try {
    const body = JSON.parse(event.body);
    const { isComplete } = body;

    // Obtener el taskId de la URL (ej. /tasks/123-abc)
    const taskId = event.pathParameters.taskId; 
    const userId = "demo_user"; // Fijo por ahora

    const command = new UpdateCommand({
      TableName: DYNAMO_TABLE,
      Key: {
        userId: userId,
        taskId: taskId,
      },
      UpdateExpression: "set isComplete = :c",
      ExpressionAttributeValues: {
        ":c": isComplete,
      },
      ReturnValues: "ALL_NEW",
    });

    const data = await ddbDocClient.send(command);

    return {
      statusCode: 200,
      headers: { "Access-Control-Allow-Origin": "*" }, // CORS
      body: JSON.stringify(data.Attributes),
    };
  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};