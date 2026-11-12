RESOURCE_GROUP="aif-prod-rg"
LOCATION="koreacentral"
REGISTRY_NAME="aifprodacr"
ENV_NAME="aif-prod-env"
CONTAINER_APP_NAME="competition-prod"
LOG_WORKSPACE_NAME="aif-prod-workspace"
APP_INSIGHTS_NAME="aif-prod-insights"

echo "Creating Container App..."
az containerapp create \
  --name $CONTAINER_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $ENV_NAME \
  --image mcr.microsoft.com/azuredocs/containerapps-helloworld:latest \
  --target-port 80 \
  --ingress 'external' \
  --min-replicas 1 \
  --cpu 1.0 \
  --memory 2.0Gi \
  --query properties.configuration.ingress.fqdn




  # 1. Container App에 System-Assigned 관리 ID 할당
  az containerapp identity assign \
    --name $CONTAINER_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --system-assigned

  # 2. 관리 ID의 Principal ID 가져오기
  PRINCIPAL_ID=$(az containerapp identity show \
    --name $CONTAINER_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --query principalId -o tsv)

  echo "Principal ID: $PRINCIPAL_ID"

  # 3. ACR Resource ID 가져오기
  ACR_ID=$(az acr show \
    --name $REGISTRY_NAME \
    --resource-group $RESOURCE_GROUP \
    --query id -o tsv)

  echo "ACR ID: $ACR_ID"

  # 4. 관리 ID에 ACR Pull 권한 부여
  az role assignment create \
    --assignee $PRINCIPAL_ID \
    --role AcrPull \
    --scope $ACR_ID

  az containerapp registry set \
    --name $CONTAINER_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --server ${REGISTRY_NAME}.azurecr.io \
    --identity system

  # 5. Container App 업데이트 (이미지 배포)
  az containerapp update \
    --name $CONTAINER_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --image ${REGISTRY_NAME}.azurecr.io/competition-prod:97bedd5215ad98a9b84a93f91babcf0c060e95cc \
    --registry-server ${REGISTRY_NAME}.azurecr.io





#managed identity aif-prod-rg 하나로 공유

#!/bin/bash

RESOURCE_GROUP="aif-prod-rg"
LOCATION="koreacentral"
REGISTRY_NAME="aifprodacr"
SHARED_IDENTITY_NAME="aif-prod-acr-identity"

echo "=== User-assigned Identity 생성 및 공유 설정 ==="

# 1. User-assigned Identity 생성
echo "1. User-assigned Identity 생성..."
az identity create \
  --name $SHARED_IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

# 2. Identity 정보 가져오기
IDENTITY_ID=$(az identity show \
  --name $SHARED_IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --query id -o tsv)

PRINCIPAL_ID=$(az identity show \
  --name $SHARED_IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --query principalId -o tsv)

CLIENT_ID=$(az identity show \
  --name $SHARED_IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --query clientId -o tsv)

echo "✓ Identity 생성 완료"
echo "  Identity ID: $IDENTITY_ID"
echo "  Principal ID: $PRINCIPAL_ID"
echo "  Client ID: $CLIENT_ID"

# 3. ACR Pull 권한 부여 (한 번만!)
echo -e "\n2. ACR Pull 권한 부여..."
ACR_ID=$(az acr show \
  --name $REGISTRY_NAME \
  --resource-group $RESOURCE_GROUP \
  --query id -o tsv)

az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role AcrPull \
  --scope $ACR_ID

echo "✓ AcrPull 권한 부여 완료"

# 권한 전파 대기
echo -e "\n권한 전파 대기 중..."
sleep 15

# 4. 모든 Container Apps에 Identity 할당
echo -e "\n3. 모든 Container Apps에 Identity 할당..."

ALL_APPS=$(az containerapp list \
  --resource-group $RESOURCE_GROUP \
  --query "[].name" -o tsv)

for APP in $ALL_APPS; do
  echo "  처리 중: $APP"

  # User-assigned Identity 할당
  az containerapp identity assign \
    --name $APP \
    --resource-group $RESOURCE_GROUP \
    --user-assigned $IDENTITY_ID \
    --output none

  # Registry 설정 변경
  az containerapp registry set \
    --name $APP \
    --resource-group $RESOURCE_GROUP \
    --server ${REGISTRY_NAME}.azurecr.io \
    --identity $IDENTITY_ID \
    --output none

  echo "    ✓ $APP 완료"
done

echo -e "\n=== 완료! ==="
echo "모든 앱이 '$SHARED_IDENTITY_NAME'를 공유합니다."

# 5. 설정 확인
echo -e "\n=== 설정 확인 ==="
for APP in $ALL_APPS; do
  REGISTRY_CONFIG=$(az containerapp show \
    --name $APP \
    --resource-group $RESOURCE_GROUP \
    --query "properties.configuration.registries[0]" \
    -o json)

  echo "$APP:"
  echo "$REGISTRY_CONFIG" | jq '{server, identity}'
done

# 6. ACR Admin 비활성화
echo -e "\n=== ACR Admin 비활성화 ==="
az acr update \
  --name $REGISTRY_NAME \
  --resource-group $RESOURCE_GROUP \
  --admin-enabled false

echo "✓ 모든 설정 완료!"




#새 서비스 추가시
#!/bin/bash

RESOURCE_GROUP="aif-prod-rg"
REGISTRY_NAME="aifprodacr"
SHARED_IDENTITY_NAME="aif-prod-acr-identity"
NEW_APP_NAME="notification-service-prod"  # 새 서비스

# Identity ID 가져오기
IDENTITY_ID=$(az identity show \
  --name $SHARED_IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --query id -o tsv)

# 새 Container App 생성 시 바로 Identity 할당
az containerapp create \
  --name $NEW_APP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment aif-prod-env \
  --image ${REGISTRY_NAME}.azurecr.io/${NEW_APP_NAME}:latest \
  --user-assigned $IDENTITY_ID \
  --registry-server ${REGISTRY_NAME}.azurecr.io \
  --registry-identity $IDENTITY_ID \
  --target-port 8080 \
  --ingress external

echo "✓ 새 서비스가 자동으로 ACR 접근 가능!"