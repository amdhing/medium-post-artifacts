#!/usr/bin/env python3
"""
AI Application using Strands SDK with Tool Calling
Simple demonstration of two agents with calculator tool

This application shows how to:
1. Create agents using the Strands SDK
2. Use official Strands tools (calculator)
3. Connect to your hosted LLM via OllamaModel
4. Ask agents questions and log responses

Based on: https://github.com/strands-agents/samples
"""

import logging
import os
from dotenv import load_dotenv

from strands import Agent
from strands.models.ollama import OllamaModel
from strands_tools.calculator import calculator

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('app.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


def main():
    """Simple demonstration of Strands SDK agents with tool calling."""

    logger.info("🚀 Starting Strands SDK Application...")

    # Create OllamaModel pointing to your hosted LLM service
    model = OllamaModel(
        model_id=os.getenv("OLLAMA_MODEL", "llama3.1:8b"),
        host=os.getenv("OLLAMA_HOST", "http://localhost:8000"),
        params={
            "max_tokens": int(os.getenv("MAX_TOKENS", "300")),
            "temperature": float(os.getenv("TEMPERATURE", "0.7")),
            "timeout": int(os.getenv("TIMEOUT", "120"))
        }
    )

    ollama_host = os.getenv('OLLAMA_HOST', 'http://localhost:8000')
    logger.info(f"🔗 Connected to LLM at: {ollama_host}")

    # Create Math Agent
    math_agent = Agent(
        model=model,
        tools=[calculator],
        system_prompt="""You are a Math Agent, an expert mathematician.

You have access to a calculator tool. Use it for all mathematical calculations.
Be concise and show your work."""
    )

    # Create Research Agent
    research_agent = Agent(
        model=model,
        tools=[calculator],
        system_prompt="""You are a Research Agent, expert at data analysis.

You have access to a calculator tool for statistical calculations.
Be analytical and show your mathematical work."""
    )

    logger.info("✅ Agents initialized successfully")

    # Question 1: Math Agent
    math_question = "What is the square root of 144?"
    logger.info(f"📝 Asking Math Agent: {math_question}")

    try:
        math_answer = math_agent(math_question)
        logger.info(f"🧮 Math Agent Answer: {math_answer}")
        print(f"\n🧮 MATH AGENT")
        print(f"Question: {math_question}")
        print(f"Answer: {math_answer}")

    except Exception as e:
        logger.error(f"❌ Math Agent error: {e}")
        print(f"❌ Math Agent failed: {e}")

    print("\n" + "="*50)

    # Question 2: Research Agent
    research_question = "Calculate the average of these numbers: 10, 15, 20, 25, 30"
    logger.info(f"📝 Asking Research Agent: {research_question}")

    try:
        research_answer = research_agent(research_question)
        logger.info(f"📊 Research Agent Answer: {research_answer}")
        print(f"\n📊 RESEARCH AGENT")
        print(f"Question: {research_question}")
        print(f"Answer: {research_answer}")

    except Exception as e:
        logger.error(f"❌ Research Agent error: {e}")
        print(f"❌ Research Agent failed: {e}")

    print("\n" + "="*50)
    logger.info("🎉 Application completed successfully!")
    print("\n🎉 Demo completed! Check app.log for detailed logs.")


if __name__ == "__main__":
    main()
