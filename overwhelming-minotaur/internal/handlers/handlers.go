package handlers

import (
	"fmt"
	"io"
	"net/http"
)

func SecretMessageHandler(w http.ResponseWriter, r *http.Request) {
	// read the body of the request
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Unable to read body", http.StatusBadRequest)
		return
	}
	defer r.Body.Close()

	fmt.Printf("Received message: %s\n", string(body))
	// send the response
	response := "I really think secret messages are silly *chuckle*"
	w.Write([]byte(response))
	fmt.Printf("Sent response: %s\n", response)
}
