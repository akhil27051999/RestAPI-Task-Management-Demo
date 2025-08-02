package com.taskapi.model;

public enum Priority {
    LOW,
    MEDIUM,
    HIGH,
    URGENT;

    public static Priority fromString(String priority) {
        for (Priority p : Priority.values()) {
            if (p.name().equalsIgnoreCase(priority)) {
                return p;
            }
        }
        throw new IllegalArgumentException("Invalid priority: " + priority);
    }
}
