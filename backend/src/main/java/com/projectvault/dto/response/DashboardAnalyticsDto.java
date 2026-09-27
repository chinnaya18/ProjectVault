package com.projectvault.dto.response;

import java.util.Map;

public class DashboardAnalyticsDto {

    private long totalProjects;
    private long approvedProjects;
    private long underReviewProjects;
    private long submittedProjects;
    private long draftProjects;
    private long rejectedProjects;
    private long archivedProjects;

    private long totalUsers;
    private long studentUsers;
    private long facultyUsers;
    private long adminUsers;
    private long alumniUsers;

    private long totalDepartments;

    private Map<String, Long> departmentProjectCounts;
    private Map<String, Long> statusCounts;
    private Map<String, Long> domainDistribution;
    private Map<String, Long> topTechStacks;

    public DashboardAnalyticsDto() {}

    public long getTotalProjects() {
        return totalProjects;
    }

    public void setTotalProjects(long totalProjects) {
        this.totalProjects = totalProjects;
    }

    public long getApprovedProjects() {
        return approvedProjects;
    }

    public void setApprovedProjects(long approvedProjects) {
        this.approvedProjects = approvedProjects;
    }

    public long getUnderReviewProjects() {
        return underReviewProjects;
    }

    public void setUnderReviewProjects(long underReviewProjects) {
        this.underReviewProjects = underReviewProjects;
    }

    public long getSubmittedProjects() {
        return submittedProjects;
    }

    public void setSubmittedProjects(long submittedProjects) {
        this.submittedProjects = submittedProjects;
    }

    public long getDraftProjects() {
        return draftProjects;
    }

    public void setDraftProjects(long draftProjects) {
        this.draftProjects = draftProjects;
    }

    public long getRejectedProjects() {
        return rejectedProjects;
    }

    public void setRejectedProjects(long rejectedProjects) {
        this.rejectedProjects = rejectedProjects;
    }

    public long getArchivedProjects() {
        return archivedProjects;
    }

    public void setArchivedProjects(long archivedProjects) {
        this.archivedProjects = archivedProjects;
    }

    public long getTotalUsers() {
        return totalUsers;
    }

    public void setTotalUsers(long totalUsers) {
        this.totalUsers = totalUsers;
    }

    public long getStudentUsers() {
        return studentUsers;
    }

    public void setStudentUsers(long studentUsers) {
        this.studentUsers = studentUsers;
    }

    public long getFacultyUsers() {
        return facultyUsers;
    }

    public void setFacultyUsers(long facultyUsers) {
        this.facultyUsers = facultyUsers;
    }

    public long getAdminUsers() {
        return adminUsers;
    }

    public void setAdminUsers(long adminUsers) {
        this.adminUsers = adminUsers;
    }

    public long getAlumniUsers() {
        return alumniUsers;
    }

    public void setAlumniUsers(long alumniUsers) {
        this.alumniUsers = alumniUsers;
    }

    public long getTotalDepartments() {
        return totalDepartments;
    }

    public void setTotalDepartments(long totalDepartments) {
        this.totalDepartments = totalDepartments;
    }

    public Map<String, Long> getDepartmentProjectCounts() {
        return departmentProjectCounts;
    }

    public void setDepartmentProjectCounts(Map<String, Long> departmentProjectCounts) {
        this.departmentProjectCounts = departmentProjectCounts;
    }

    public Map<String, Long> getStatusCounts() {
        return statusCounts;
    }

    public void setStatusCounts(Map<String, Long> statusCounts) {
        this.statusCounts = statusCounts;
    }

    public Map<String, Long> getDomainDistribution() {
        return domainDistribution;
    }

    public void setDomainDistribution(Map<String, Long> domainDistribution) {
        this.domainDistribution = domainDistribution;
    }

    public Map<String, Long> getTopTechStacks() {
        return topTechStacks;
    }

    public void setTopTechStacks(Map<String, Long> topTechStacks) {
        this.topTechStacks = topTechStacks;
    }
}
