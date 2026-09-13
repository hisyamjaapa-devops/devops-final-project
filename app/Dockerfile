# Stage 1: Build app guna Node.js
FROM node:20 AS build

WORKDIR /app

COPY package*.json ./

RUN npm clean-install

COPY . .

RUN npm run build


# Stage 2: Run app guna Nginx
FROM nginx:alpine

COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
