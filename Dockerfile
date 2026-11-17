FROM node:22-alpine AS build
WORKDIR /app
ARG NPM_REGISTRY
COPY package*.json ./
RUN if [ -n "$NPM_REGISTRY" ]; then npm config set registry "$NPM_REGISTRY"; fi && npm ci
COPY . .
RUN npm run build -- --configuration production

FROM nginx:alpine
ARG DIST_DIR=dist/my-app/browser
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/${DIST_DIR} /usr/share/nginx/html
EXPOSE 80
