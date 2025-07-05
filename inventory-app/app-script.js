// This app script function should not be run manually as this can be done using the triggers UI, if we run it manually after saving, it will log and error in the execution log and this is becacuse the (e) expects a variable from the form submission
function sendToAPIGateway(e) {
  const data = {
    timestamp: e.values[0],
    email: e.values[1],
    product: e.values[2],
    seller: e.values[3],
    customerName: e.values[4],
    dateSold: e.values[5],
    timeSold: e.values[6],
    modelNumber: e.values[7]
  };

  const options = {
    method: 'post',
    contentType: 'application/json',
    payload: JSON.stringify(data)
  };

  const url = 'AWS APIGATEWAY url/route';

  UrlFetchApp.fetch(url, options);
}

// NOTE: go to the triggers UI on the left hand corner and set up triggers for form submissions, you can test the sendToAPIGateway script using the sample code below
function sendToAPIGateway(e) {
  const data = {
    timestamp: e.values[0],
    email: e.values[1],
    product: e.values[2],
    seller: e.values[3],
    customerName: e.values[4],
    dateSold: e.values[5],
    timeSold: e.values[6],
    modelNumber: e.values[7]
  };

  Logger.log("Sending this data: " + JSON.stringify(data));

  const options = {
    method: 'post',
    contentType: 'application/json',
    payload: JSON.stringify(data)
  };

  const url = 'API-GATWWAY-endpoint-url/lambda-route';

  UrlFetchApp.fetch(url, options);
}

function testSendToAPIGateway() {
  const mockEvent = {
    values: [
      "2025-06-01T12:00:00Z",
      "testuser@example.com",
      "Laptop",
      "John Doe",
      "Jane Smith",
      "2025-05-31",
      "14:30",
      "ABC123"
    ]
  };

  sendToAPIGateway(mockEvent);
}


