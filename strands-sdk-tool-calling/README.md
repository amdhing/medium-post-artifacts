# Strands SDK Tool Calling Application

A simple AI application demonstrating proper Strands SDK usage with tool calling capabilities, connecting to your hosted LLM from Article 1.

## 🎯 What This Demonstrates

This application shows the **correct agentic patterns** for using Strands SDK:

- **Simple Agent Creation**: Following official Strands samples approach
- **Official Tools Integration**: Using `strands_tools.calculator` 
- **Hosted LLM Connection**: Connecting to your FastAPI service via OllamaModel
- **Multi-Agent Architecture**: Math Agent and Research Agent with specialized roles
- **Tool Calling**: Real calculator usage with proper logging

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Strands SDK   │    │   FastAPI        │    │     Ollama      │
│   Application   │───▶│   Service        │───▶│   LLM Engine    │
│   (This Code)   │    │  (Article 1)     │    │  (Article 1)    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### 1. Prerequisites

Make sure you have:
- ✅ **Python 3.10 or above** (Strands SDK requirement)
- ✅ Completed **Article 1** with EC2 instance running
- ✅ LLM service accessible at `http://your-ec2-instance:8000`
- ✅ Health check passing: `curl http://your-ec2-instance:8000/health`

### 2. Installation

```bash
# Clone or download the artifacts
cd strands-sdk-tool-calling

# Install dependencies
pip install -r requirements.txt
```

### 3. Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your EC2 instance details
OLLAMA_HOST=http://your-ec2-instance:8000
OLLAMA_MODEL=llama3.1:8b
```

### 4. Run the Application

```bash
python main.py
```

**Expected Output:**
```
🚀 Starting Strands SDK Application...
🔗 Connected to LLM at: http://your-ec2-instance:8000
✅ Agents initialized successfully

🧮 MATH AGENT
Question: What is the square root of 144?
Answer: The square root of 144 is 12.

==================================================

📊 RESEARCH AGENT
Question: Calculate the average of these numbers: 10, 15, 20, 25, 30
Answer: The average is 20.

==================================================

🎉 Demo completed! Check app.log for detailed logs.
```

## 🎮 What the Application Does

The application is intentionally simple and demonstrates core concepts:

### 1. Agent Initialization
- Creates two specialized agents (Math and Research)
- Connects both to your hosted LLM service
- Provides each with the official Strands calculator tool

### 2. Question & Answer Demo
- **Math Agent**: Asks "What is the square root of 144?"
- **Research Agent**: Asks "Calculate the average of these numbers: 10, 15, 20, 25, 30"
- Both agents use the calculator tool to compute answers

### 3. Comprehensive Logging
- Logs all questions and answers
- Records HTTP requests to your LLM service
- Creates `app.log` file with detailed information
- Shows tool calling in action

## 🛠️ Key Features

### Math Agent Capabilities
- **Mathematical Calculations**: Square roots, equations, algebra
- **Tool Integration**: Uses calculator for all computations
- **Clear Explanations**: Shows work and reasoning

### Research Agent Capabilities  
- **Statistical Analysis**: Averages, data processing
- **Analytical Approach**: Structured problem solving
- **Mathematical Rigor**: Uses calculator for precision

### Calculator Tool Features
- **Multiple Modes**: evaluate, solve, derive, integrate, limit, series, matrix
- **High Precision**: SymPy-powered mathematical engine
- **Rich Output**: Formatted results with detailed information
- **Error Handling**: Robust validation and error messages

## 🔧 Code Structure

```
strands-sdk-tool-calling/
├── main.py              # Simple demo with two agent questions
├── requirements.txt     # Dependencies (Python 3.10+ required)
├── .env.example        # Configuration template
├── app.log             # Generated log file (after running)
└── README.md           # This file
```

**Key Design Principles:**
- ✅ **Simple**: No complex interactions, just two questions
- ✅ **Official Tools**: Uses `strands_tools.calculator` 
- ✅ **Clear Logging**: Every step is logged and visible
- ✅ **Proper Patterns**: Follows official Strands SDK examples

## 🧪 Testing

### Manual Testing
```bash
# Test calculator directly
python -c "from strands_tools.calculator import calculator; print(calculator(expression='2+2'))"

# Test LLM connection
curl http://your-ec2-instance:8000/health
```

### Log Analysis
```bash
# View detailed logs after running main.py
tail -f app.log
```

## 🐛 Troubleshooting

### Connection Issues
```bash
# Check if your LLM service is running
curl http://your-ec2-instance:8000/health

# Expected response:
{"status":"healthy","ollama_status":"healthy","available_models":["llama3.1:8b"]}
```

### Python Version Issues
```bash
# Check Python version (must be 3.10+)
python --version

# If you have multiple Python versions, you may need to use:
python3 --version
# or
python3.10 --version
# or
python3.11 --version
```

### Import Errors
```bash
# Make sure you have the right packages
pip install strands-agents==1.0.0 strands-agents-tools==0.2.0

# Test imports
python -c "from strands import Agent; from strands_tools.calculator import calculator; print('✅ Imports successful')"
```

### If You Have Python Version Issues
If your system's default `python` is below 3.10, you may need to use a specific version:

```bash
# Use specific Python version
python3.10 main.py
# or
python3.11 main.py

# Install packages with specific version
python3.10 -m pip install -r requirements.txt
```

## 📊 Understanding the Output

### Successful Tool Calling
When you see output like this, tool calling is working:
```
Tool #1: calculator
The square root of 144 is 12.
```

### Log File Contents
The `app.log` file contains:
- Agent initialization messages
- Questions asked to each agent
- Full responses from agents
- HTTP requests to your LLM service
- Timing and performance information

### Expected Behavior
- **Math Agent**: Should use calculator for square root calculation
- **Research Agent**: Should use calculator for average calculation
- **Both**: Should show "Tool #1: calculator" indicating tool usage
- **Logs**: Should show successful HTTP requests to port 8000

## 🎯 Next Steps

1. **Modify Questions**: Edit `main.py` to ask different questions
2. **Add More Agents**: Create specialized agents for other domains
3. **Extend Tools**: Add more Strands tools (web search, file operations)
4. **Production Deploy**: Containerize and deploy to AWS ECS/EKS

## 📚 Learning Resources

- **Strands Documentation**: https://strandsagents.com/latest/documentation/docs/
- **Official Samples**: https://github.com/strands-agents/samples
- **Calculator Tool**: https://github.com/strands-agents/tools
- **Article 1**: Host Your Own LLM on EC2 (prerequisite)

## 📄 License

MIT License - Feel free to use this code in your own projects!
