MODE = Release
BIN = bin/$(MODE)/net8.0

transpiler:
	dotnet build Drizzle.Transpiler /p:Configuration=$(MODE)

ported:
	Drizzle.Transpiler/$(BIN)/Drizzle.Transpiler

drizzle: ported
	dotnet build /p:Configuration=$(MODE)

run:
	Drizzle.Editor/$(BIN)/Drizzle.Editor