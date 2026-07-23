FROM node:20-bookworm

WORKDIR /app

COPY package.json ./
RUN npm install

COPY src ./src
COPY scripts ./scripts

EXPOSE 3000 3001

CMD ["npm", "run", "start"]
