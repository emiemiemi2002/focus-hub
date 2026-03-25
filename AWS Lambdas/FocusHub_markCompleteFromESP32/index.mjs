import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, UpdateCommand } from "@aws-sdk/lib-dynamodb";

const DYNAMO_TABLE = "FocusHub_Tasks";
const dbClient = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(dbClient);

export const handler = async (event) => {
  // El 'event' aquí viene de IoT Core, no de API Gateway
  try {
    const { taskId } = event; // Asumimos que el ESP32 envía {"taskId": "123-abc"}
    const userId = "demo_user"; 

    if (!taskId) {
      throw new Error("taskId no fue proporcionado en el evento de IoT");
    }

    const command = new UpdateCommand({
      TableName: DYNAMO_TABLE,
      Key: {
        userId: userId,
        taskId: taskId,
      },
      UpdateExpression: "set isComplete = :c",
      ExpressionAttributeValues: {
        ":c": true, // El ESP32 solo marca como completado
      },
    });

    await ddbDocClient.send(command);
    console.log(`Tarea ${taskId} marcada como completa.`);

    return { message: "OK" };

  } catch (error) {
    console.error(error);
  }
};