/*
The MIT License (MIT)

Copyright (c) 2018 Slava Monich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#include "ContactsPlugin.h"

// Workaround for org.nemomobile.contacts not being allowed in harbour apps

// ==========================================================================
// ContactsPlugin
// ==========================================================================

ContactsPlugin* ContactsPlugin::gInstance = NULL;

ContactsPlugin::ContactsPlugin(
    QQmlEngine* aEngine) :
    HarbourPluginLoader(aEngine, "org.nemomobile.contacts", 1, 0)
{
}

void
ContactsPlugin::registerTypes(
    const char* aModule,
    int aMajor,
    int aMinor)
{
    reRegisterType("PeopleVCardModel", aModule, aMajor, aMinor);
}

void
ContactsPlugin::registerTypes(
    QQmlEngine* aEngine,
    const char* aModule,
    int aMajor,
    int aMinor)
{
    if (!gInstance) {
        gInstance = new ContactsPlugin(aEngine);
    }
    gInstance->registerTypes(aModule, aMajor, aMinor);
}
