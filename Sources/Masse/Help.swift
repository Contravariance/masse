func syntax() -> Never {
    print("Syntax:")
    print("masse [path to configuration file].bacf")
    exit(0)
}

func failedExecution(_ error: String) -> Never {
    print("Execution Failed with Error:")
    print("'\(error)'")
    exit(1)
}

func log(_ message: String) {
    print(message)
}
