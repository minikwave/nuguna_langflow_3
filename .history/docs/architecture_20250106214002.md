# Architecture

## Overview
This project is a web-based testing infrastructure for validating and improving Text-to-SQL chatbot performance, built with Langflow and Flask.

## Components
1. **Langflow Integration**: Processes natural language queries into SQL.
2. **Sample Databases**: SQLite databases for testing.
3. **Admin Dashboard**: Displays system status and allows workflow management.
4. **Testing Framework**: Unit and integration tests to validate system functionality.

## Data Flow
1. User input → Flask API (`/kakao`) → Langflow (`/api/infer`) → SQL Query.
2. SQL Query → SQLite Database → Query Result → Kakao Response Template.

## Key Features
- Multiple databases for scenario testing.
- Modular code structure for scalability.
- Comprehensive logging and error handling.
