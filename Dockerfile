# Fleetman web app (Angular 19), multi-stage build.
# The doc's version copied a pre-built /dist (and faked it with `mv src dist`);
# here stage 1 really compiles the Angular app, stage 2 serves the result with nginx.

# ---- Stage 1: build the Angular app ----
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
RUN npx ng build --configuration production

# ---- Stage 2: serve it with nginx ----
# nginx:stable-alpine replaces the author's nginx:1.14.0-alpine (2018, unmaintained)
FROM nginx:stable-alpine
RUN rm -rf /usr/share/nginx/html/*
COPY --from=build /app/dist/fleetman-webapp/browser/ /usr/share/nginx/html/
# proxies /api/ to the fleetman-api-gateway Service inside the cluster
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
