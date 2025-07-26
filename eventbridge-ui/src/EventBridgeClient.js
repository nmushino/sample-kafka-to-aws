import { EventBridgeClient, PutEventsCommand } from "@aws-sdk/client-eventbridge";
import { fromCognitoIdentityPool } from "@aws-sdk/credential-provider-cognito-identity";
import { Amplify } from "aws-amplify";
import awsconfig from "./aws-exports";

Amplify.configure(awsconfig);

// クライアント
const client = new EventBridgeClient({
  region: process.env.REACT_APP_AWS_REGION,
  credentials: process.env.REACT_APP_AWS_ACCESS_KEY_ID
    ? {
        accessKeyId: process.env.REACT_APP_AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.REACT_APP_AWS_SECRET_ACCESS_KEY,
      }
    : fromCognitoIdentityPool({
        clientConfig: { region: process.env.REACT_APP_AWS_REGION },
        identityPoolId: process.env.REACT_APP_COGNITO_IDENTITY_POOL_ID,
      }),
});

// イベント送信関数
export const sendEvent = async (detailType, detailData) => {
  try {
    const command = new PutEventsCommand({
      Entries: [
        {
          Source: "eventbridge.app",
          DetailType: detailType,
          EventBusName: process.env.REACT_APP_EVENT_BUS_NAME,
          Detail: JSON.stringify({ data: detailData }),
        },
      ],
    });

    const response = await client.send(command);
    console.log("イベント送信成功:", response);
    return response;
  } catch (error) {
    console.error("イベント送信エラー:", error);
    throw error;
  }
};