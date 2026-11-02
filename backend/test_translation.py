from translation_service import translate_text

text = "My soybean crop is growing well."

print("First request:")
print(translate_text(text, "mr"))

print("\nSecond request:")
print(translate_text(text, "mr"))