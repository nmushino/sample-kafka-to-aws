
const awsconfig = () => ({
  aws_project_region: window._env_?.REACT_APP_AWS_REGION || "",
  aws_cognito_identity_pool_id: window._env_?.REACT_APP_IDENTITY_POOL_ID || "",
  aws_cognito_region: window._env_?.REACT_APP_AWS_REGION || "",
  aws_user_pools_id: window._env_?.REACT_APP_USER_POOL_ID || "",
  aws_user_pools_web_client_id: window._env_?.REACT_APP_USER_POOL_CLIENT_ID || "",
});

export default awsconfig;