import 'dart:io';

/// On the phone: no network shows as a socket or HTTP error.
bool isIoNetworkError(Object error) =>
    error is SocketException || error is HttpException;
