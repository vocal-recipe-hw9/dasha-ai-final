const dasha = require("@dasha.ai/sdk");
// const fs = require("fs");
const { v4: uuidv4 } = require("uuid");
const express = require("express");
const cors = require("cors");

const expressApp = express();
expressApp.use(express.json());
expressApp.use(cors());

const axios = require("axios").default;

const main = async () => {
  const app = await dasha.deploy(`${__dirname}/app`);

  // External function name
  app.setExternal("name", async(args, conv) => {
    const inputData = args.name;
    console.log("search name is " + inputData);

    const res = await axios.get(`https://api.spoonacular.com/recipes/complexSearch?apiKey=ecb1f2a12d6a4fb1942aa1d3703eaea6&query= ${inputData}`);
    console.log(" JSON data from API ==>", res.data);

    var searchResult = [];
    for (var i = 0; i < res.data.results.length; i++){
      searchResult.push(res.data.results[i].title);
    }
    return searchResult;

  });
  
  app.setExternal("findName", async(args, conv) => {
    const inputChoice = args.findName;
    console.log("id is " + inputChoice);
    const res = await axios.get(`https://api.spoonacular.com/recipes/complexSearch?apiKey=ecb1f2a12d6a4fb1942aa1d3703eaea6&query= ${inputChoice}`);
    console.log(" JSON data from API ==>", res.data);

    var recipeID = res.data.results[0].id;
    const id = await axios.get(`https://api.spoonacular.com/recipes/${recipeID}/information?apiKey=ecb1f2a12d6a4fb1942aa1d3703eaea6&includeNutrition=false`);
    console.log(" JSON data from API ==>", id.data);
    
    
    var stepResult = [];
    for (var i = 0; i < id.data.analyzedInstructions[0].steps.length; i++){
      stepResult.push(id.data.analyzedInstructions[0].steps[i].step);
    }
    return stepResult;

  });

  await app.start({ concurrency: 10 });

  expressApp.get("/sip", async (req, res) => {
    const domain = app.account.server.replace("app.", "sip.");
    const endpoint = `wss://${domain}/sip/connect`;

    // client sip address should:
    // 1. start with `sip:reg`
    // 2.  be unique
    // 3. use the domain as the sip server
    const aor = `sip:reg-${uuidv4()}@${domain}`;

    res.send({ aor, endpoint });
  });

  expressApp.post("/call", async (req, res) => {
    const { aor, name } = req.body;
    res.sendStatus(200);

    console.log("Start call for", req.body);
    const conv = app.createConversation({ endpoint: aor, name });
    conv.on("transcription", console.log);
    conv.audio.tts = "dasha";
    conv.audio.noiseVolume = 0;

    await conv.execute();
  });

  const server = expressApp.listen(8000, () => {
    console.log("Api started on port 8000.");
  });

  process.on("SIGINT", () => server.close());
  server.once("close", async () => {
    await app.stop();
    app.dispose();
  });
};

main();
