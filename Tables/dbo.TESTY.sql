CREATE TABLE [dbo].[TESTY]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[WORDS] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[NUMBERS] [int] NULL,
[numer] [numeric] (4, 2) NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TESTY] ADD CONSTRAINT [PK__TESTY__3214EC27FD544B6C] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
