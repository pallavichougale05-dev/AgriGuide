from transformers import pipeline

MODEL_NAME = "Helsinki-NLP/opus-mt-en-mr"

print("Loading English to Marathi translation model...")

translator = pipeline(
    "translation",
    model=MODEL_NAME,
    device=-1
)

text = "My cotton leaves are turning yellow. What should I do?"

result = translator(text, max_length=128)

print("\nOriginal English:")
print(text)

print("\nMarathi Translation:")
print(result[0]["translation_text"])