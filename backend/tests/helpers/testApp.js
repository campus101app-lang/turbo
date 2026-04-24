import express from 'express';

export function createRouteTestApp(routePath, routeModule) {
  const app = express();
  app.use(express.json());
  app.use(routePath, routeModule);
  return app;
}
