describe("mediaWorkerDispatch module", () => {
  test("module exports are defined", () => {
    const mod = require("./index");
    expect(mod.mediaWorkerDispatch).toBeDefined();
    expect(mod.retryMediaWorkerJob).toBeDefined();
  });
});
