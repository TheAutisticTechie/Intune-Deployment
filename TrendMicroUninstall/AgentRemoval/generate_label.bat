@echo off
for /F "delims=" %%l in (%1) do (
	if "$$l" NEQ "" echo %%l
)
