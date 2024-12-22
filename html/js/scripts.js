// Updated the visitor count on the screen when the page is loaded
document.addEventListener('DOMContentLoaded', function() { 
    const apiUrl = 'https://m5co4evo25.execute-api.us-east-1.amazonaws.com/prod/visitor_count';
    fetch(apiUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
      })
      .then((response) => response.json())
        .then((data) => {
            document.getElementById("visitors").innerHTML = data.body.visitorCount;
        })
        .catch((error) => {
            console.error('Error:', error);
        });
});