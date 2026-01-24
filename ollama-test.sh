#!/bin/bash

# Test script for Ollama container

# Get the IP address of the ollama-main container
OLLAMA_IP=$(docker inspect ollama-main --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)

if [ -z "$OLLAMA_IP" ]; then
    echo "Error: ollama-main container not found or not running"
    exit 1
fi

echo "Found ollama-main at IP: $OLLAMA_IP"
echo "Testing Ollama API..."
echo ""

# Test 1: Pull the model
echo "Step 1: Pulling qwen3:0.6b model..."
curl -X POST http://$OLLAMA_IP:11434/api/pull -d '{"name": "qwen3:0.6b"}'
echo ""
echo ""

# Wait a bit for the model to be ready
echo "Waiting for model to be ready..."
sleep 2
echo ""

# Test 2: Ask a question
echo "Step 2: Asking a question to the model..."
curl -X POST http://$OLLAMA_IP:11434/api/generate -d '{"model": "qwen3:0.6b", "prompt": "What is the capital of France?", "stream": false}'
echo ""
echo ""

echo "Test complete!"
