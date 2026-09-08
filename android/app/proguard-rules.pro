# Required by sqflite_sqlcipher if/when release code shrinking is enabled —
# without this, ProGuard/R8 strips the native SQLCipher bindings it needs.
-keep class net.sqlcipher.** { *; }
