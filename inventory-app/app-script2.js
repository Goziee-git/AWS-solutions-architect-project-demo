function sendLatestFormResponse() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
  Logger.log('Active sheet name: ' + sheet.getName());

  const lastRow = sheet.getLastRow();
  Logger.log('Last row number (latest response): ' + lastRow);

  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  Logger.log('Headers: ' + JSON.stringify(headers));

  const values = sheet.getRange(lastRow, 1, 1, sheet.getLastColumn()).getValues()[0];
  Logger.log('Latest row values: ' + JSON.stringify(values));

  // Build a JSON object from headers and latest values
  const payload = {};
  headers.forEach((key, index) => {
    payload[key] = values[index];
  });

  Logger.log('Constructed JSON payload: ' + JSON.stringify(payload, null, 2));

  // Send to AWS API Gateway
  const url = 'AWS-API-GATEWAY-endpoint/lambda-route'; // Replace with your actual endpoint
  const options = {
    method: 'POST',
    contentType: 'application/json',
    payload: JSON.stringify(payload),
    muteHttpExceptions: true
  };

  try {
    const response = UrlFetchApp.fetch(url, options);
    Logger.log('API Gateway response code: ' + response.getResponseCode());
    Logger.log('API Gateway response body: ' + response.getContentText());
  } catch (e) {
    Logger.log('Error sending request to API Gateway: ' + e.message);
  }
}
