import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import { IoTDataPlaneClient, UpdateThingShadowCommand } from "@aws-sdk/client-iot-data-plane";

const DYNAMO_TABLE = "FocusHub_Tasks";
const IOT_THING_NAME = "FocusHub_ESP32";

const dbClient = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(dbClient);
const iotClient = new IoTDataPlaneClient({});

export const handler = async (event) => {
  try {
    // 1. Parsear los datos de la app
    const body = JSON.parse(event.body);
    const { taskId, taskName, userId } = body;

    // 2. Crear la tarea en DynamoDB
    const dbCommand = new PutCommand({
      TableName: DYNAMO_TABLE,
      Item: {
        userId: userId,
        taskId: taskId,
        taskName: taskName,
        isComplete: false,
        createdAt: Date.now(),
      },
    });
    await ddbDocClient.send(dbCommand);

    // 3. Sincronizar la nueva tarea con el ESP32 (actualizar la Sombra)
    // (Nota: Esto es una lógica simple, en un mundo real se haría un 'get-y-append')
    // Por ahora, le enviamos la tarea nueva. El ESP32 la deberá añadir a su lista.
    // Una lógica mejor es leer primero la lista de tareas de DynamoDB y enviarla completa.
    // Pero para este proyecto, podemos simplificar:
    const shadowPayload = {
      state: {
        desired: {
          lastNewTask: { id: taskId, name: taskName } // El ESP32 debe leer esto
        }
      }
    };

    const iotCommand = new UpdateThingShadowCommand({
      thingName: IOT_THING_NAME,
      payload: JSON.stringify(shadowPayload),
    });
    await iotClient.send(iotCommand);

    // 4. Responder a la app
    return {
      statusCode: 201,
      headers: { "Access-Control-Allow-Origin": "*" }, // CORS
      body: JSON.stringify({ message: "Tarea creada y sincronizada" }),
    };
  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};