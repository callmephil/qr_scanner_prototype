const express = require("express");
const cors = require("cors");
const { v4: uuidv4 } = require("uuid");

const app = express();
const port = 3000;

// Enable CORS
app.use(cors());

// POST route to handle dynamic :id as a parameter
// @ts-ignore
app.post("/:id", (req, res) => {
  const { id } = req.params;

  if (!id) {
    console.error(`NOT Responded with ID: ${id}`);
    return res.status(400).json({ error: "ID parameter is required." });
  }

  console.log(`Received ID: ${id}`);

  // Generate a UUID
  const uuid = uuidv4();

  // Respond with the received ID and generated UUID
  res.status(200).json({ message: "ID received successfully.", id, uuid });
});

// Start the server
app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
