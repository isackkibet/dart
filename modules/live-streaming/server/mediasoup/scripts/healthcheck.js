const port = process.env.API_PORT || 3000;

fetch(`http://127.0.0.1:${port}/health`)
  .then((response) => {
    if (!response.ok) {
      console.error(`Healthcheck failed with status ${response.status}`);
      process.exit(1);
    }
    return response.json();
  })
  .then((body) => {
    if (!body.ok) {
      console.error("Healthcheck body not OK");
      process.exit(1);
    }
    process.exit(0);
  })
  .catch((error) => {
    console.error("Healthcheck failed", error);
    process.exit(1);
  });
