FROM ollama/ollama:latest

# Expose the default Ollama port
EXPOSE 11434

# Set the default command to run Ollama server
CMD ["serve"]
