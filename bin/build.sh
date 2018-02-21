#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
tar -cvf ./streamsets.tar ./streamsets/*
tar -cvf ./bootstrap.tar ./bootstrap/*
