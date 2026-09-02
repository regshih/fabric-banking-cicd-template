CREATE TABLE [dbo].[EnvironmentConfig]
(
    [ConfigKey]   NVARCHAR(128) NOT NULL,
    [ConfigValue] NVARCHAR(512) NOT NULL,
    [IsSecret]    BIT           NOT NULL CONSTRAINT [DF_EnvironmentConfig_IsSecret] DEFAULT (0),
    CONSTRAINT [PK_EnvironmentConfig] PRIMARY KEY CLUSTERED ([ConfigKey]),
    CONSTRAINT [CK_EnvironmentConfig_NoSecrets] CHECK ([IsSecret] = 0)
);
