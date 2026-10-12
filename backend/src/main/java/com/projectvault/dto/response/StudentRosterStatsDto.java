package com.projectvault.dto.response;

public class StudentRosterStatsDto {
    private long totalStudents;
    private long registeredStudents;
    private long eligibleStudents;
    private long discontinuedStudents;

    public StudentRosterStatsDto() {}

    public StudentRosterStatsDto(long totalStudents, long registeredStudents, long eligibleStudents, long discontinuedStudents) {
        this.totalStudents = totalStudents;
        this.registeredStudents = registeredStudents;
        this.eligibleStudents = eligibleStudents;
        this.discontinuedStudents = discontinuedStudents;
    }

    public long getTotalStudents() {
        return totalStudents;
    }

    public void setTotalStudents(long totalStudents) {
        this.totalStudents = totalStudents;
    }

    public long getRegisteredStudents() {
        return registeredStudents;
    }

    public void setRegisteredStudents(long registeredStudents) {
        this.registeredStudents = registeredStudents;
    }

    public long getEligibleStudents() {
        return eligibleStudents;
    }

    public void setEligibleStudents(long eligibleStudents) {
        this.eligibleStudents = eligibleStudents;
    }

    public long getDiscontinuedStudents() {
        return discontinuedStudents;
    }

    public void setDiscontinuedStudents(long discontinuedStudents) {
        this.discontinuedStudents = discontinuedStudents;
    }
}
