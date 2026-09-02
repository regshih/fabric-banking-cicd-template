CREATE TABLE [dbo].[RiskThreshold]
(
    [RiskCode]       NVARCHAR(32)  NOT NULL,
    [ThresholdValue] DECIMAL(18,2) NOT NULL,
    [Description]    NVARCHAR(256) NOT NULL,
    [UpdatedAtUtc]   DATETIME2(3)  NOT NULL CONSTRAINT [DF_RiskThreshold_UpdatedAtUtc] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_RiskThreshold] PRIMARY KEY CLUSTERED ([RiskCode])
);
