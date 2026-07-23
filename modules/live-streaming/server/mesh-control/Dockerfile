FROM node:22-alpine AS build
WORKDIR /workspace
COPY contracts/mesh-live/package*.json contracts/mesh-live/
COPY server/mesh-control/package*.json server/mesh-control/
RUN cd contracts/mesh-live && npm ci && cd ../../server/mesh-control && npm ci
COPY contracts/mesh-live contracts/mesh-live
COPY server/mesh-control server/mesh-control
RUN cd contracts/mesh-live && npm run build && cd ../../server/mesh-control && npm run build

FROM node:22-alpine
WORKDIR /workspace/server/mesh-control
ENV NODE_ENV=production
COPY --from=build /workspace/contracts/mesh-live /workspace/contracts/mesh-live
COPY --from=build /workspace/server/mesh-control/package*.json ./
RUN npm ci --omit=dev
COPY --from=build /workspace/server/mesh-control/dist ./dist
EXPOSE 8080
CMD ["node", "dist/server.js"]
