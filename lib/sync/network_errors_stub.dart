/// In the browser, a failed request surfaces as an `http` ClientException,
/// which `guardServer` handles itself; there is no socket error to check.
bool isIoNetworkError(Object error) => false;
