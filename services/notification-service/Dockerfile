# ビルドステージ
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app
COPY *.csproj .
RUN dotnet restore -q
COPY . .
RUN dotnet publish -c Release -o /out --no-restore -q

# 実行ステージ
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /out .
EXPOSE 8081
ENTRYPOINT ["dotnet", "notification-service.dll"]
