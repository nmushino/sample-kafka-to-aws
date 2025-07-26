import { EventBridgeClient, PutEventsCommand } from "@aws-sdk/client-eventbridge";
import { fromCognitoIdentityPool } from "@aws-sdk/credential-provider-cognito-identity";
import { Amplify } from "aws-amplify";
import awsconfig from "./aws-exports";

// Amplify は環境変数からの値を使って設定されている想定
Amplify.configure(awsconfig);

// 実行時に動的に環境変数を取得できるようにwindow._env_を使う場合の例
const REGION = window._env_?.REACT_APP_AWS_REGION || process.env.REACT_APP_AWS_REGION || "ap-northeast-1";
const ACCESS_KEY_ID = window._env_?.REACT_APP_AWS_ACCESS_KEY_ID || process.env.REACT_APP_AWS_ACCESS_KEY_ID;
const SECRET_ACCESS_KEY = window._env_?.REACT_APP_AWS_SECRET_ACCESS_KEY || process.env.REACT_APP_AWS_SECRET_ACCESS_KEY;
const IDENTITY_POOL_ID = window._env_?.REACT_APP_COGNITO_IDENTITY_POOL_ID || process.env.REACT_APP_COGNITO_IDENTITY_POOL_ID;
const EVENT_BUS_NAME = window._env_?.REACT_APP_EVENT_BUS_NAME || process.env.REACT_APP_EVENT_BUS_NAME;

// クライアント生成は関数化して、毎回最新の環境変数で作成する形にするのがおすすめ
const createEventBridgeClient = () => {
  if ((!ACCESS_KEY_ID || !SECRET_ACCESS_KEY) && !IDENTITY_POOL_ID) {
    console.error("Missing values:", {
      ACCESS_KEY_ID,
      SECRET_ACCESS_KEY,
      IDENTITY_POOL_ID,
    });
    throw new Error("AWS credentials or Cognito Identity Pool ID are not set");
  }
  
  const client = new EventBridgeClient({
    region: REGION,
    credentials: ACCESS_KEY_ID
      ? {
          accessKeyId: ACCESS_KEY_ID,
          secretAccessKey: SECRET_ACCESS_KEY,
        }
      : fromCognitoIdentityPool({
          clientConfig: { region: REGION },
          identityPoolId: IDENTITY_POOL_ID,
        }),
  });
};

// イベント送信関数
export const sendEvent = async (detailType, detailData) => {
  const client = createEventBridgeClient();
  try {
    const command = new PutEventsCommand({
      Entries: [
        {
          Source: "eventbridge.app",
          DetailType: detailType,
          EventBusName: EVENT_BUS_NAME,
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