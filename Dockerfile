FROM mcr.microsoft.com/playwright:v1.39.0-jammy
RUN npm install -g netlify-cli@17.10.1 node-jq serve
