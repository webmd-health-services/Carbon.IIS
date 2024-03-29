
enum CIisNumaNodeAffinityMode
{
    Soft = [UInt32]0
    Hard = [UInt32]1
}

enum CIisNumaNodeAssignment
{
    MostAvailableMemory = [UInt32]0
    WindowsScheduling = [UInt32]1
}

enum CIisProcessModelLogonType
{
    Batch = 0
    Service = 1
}

enum CIisHttpRedirectResponseStatus
{
    Permanent = 301
    Found = 302
    Temporary = 307
    PermRedirect = 308
}

[Flags()]
enum CIisHttpsFlags
{
    None = 0
    Ssl = 8
    SslNegotiateCert = 32
    SslRequireCert = 64
    SslMapCert = 128
    Ssl128 = 256
}