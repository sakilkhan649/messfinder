	at org.jetbrains.kotlin.buildtools.internal.KotlinToolchainsImpl$BuildSessionImpl.executeOperation$lambda$1(KotlinToolchainsImpl.kt:70)
	at org.jetbrains.kotlin.buildtools.internal.KotlinToolchainsImpl$BuildSessionImpl.executeOperation(KotlinToolchainsImpl.kt:74)
	at org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork.performCompilation(BuildToolsApiCompilationWork.kt:172)
	at org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork.compileInDaemon(BuildToolsApiCompilationWork.kt:244)
	at org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork.execute(BuildToolsApiCompilationWork.kt:285)
	at org.gradle.workers.internal.DefaultWorkerServer.execute(DefaultWorkerServer.java:63)
	at org.gradle.workers.internal.NoIsolationWorkerFactory$1$1.create(NoIsolationWorkerFactory.java:66)
	at org.gradle.workers.internal.NoIsolationWorkerFactory$1$1.create(NoIsolationWorkerFactory.java:62)
	at org.gradle.internal.classloader.ClassLoaderUtils.executeInClassloader(ClassLoaderUtils.java:100)
	at org.gradle.workers.internal.NoIsolationWorkerFactory$1.lambda$execute$0(NoIsolationWorkerFactory.java:62)
	at org.gradle.workers.internal.AbstractWorker$1.call(AbstractWorker.java:44)
	at org.gradle.workers.internal.AbstractWorker$1.call(AbstractWorker.java:41)
	at org.gradle.internal.operations.DefaultBuildOperationRunner$CallableBuildOperationWorker.execute(DefaultBuildOperationRunner.java:209)
	at org.gradle.internal.operations.DefaultBuildOperationRunner$CallableBuildOperationWorker.execute(DefaultBuildOperationRunner.java:204)
	at org.gradle.internal.operations.DefaultBuildOperationRunner$2.execute(DefaultBuildOperationRunner.java:66)
	at org.gradle.internal.operations.DefaultBuildOperationRunner$2.execute(DefaultBuildOperationRunner.java:59)
	at org.gradle.internal.operations.DefaultBuildOperationRunner.execute(DefaultBuildOperationRunner.java:166)
	at org.gradle.internal.operations.DefaultBuildOperationRunner.execute(DefaultBuildOperationRunner.java:59)
	at org.gradle.internal.operations.DefaultBuildOperationRunner.call(DefaultBuildOperationRunner.java:53)
	at org.gradle.workers.internal.AbstractWorker.executeWrappedInBuildOperation(AbstractWorker.java:41)
	at org.gradle.workers.internal.NoIsolationWorkerFactory$1.execute(NoIsolationWorkerFactory.java:59)
	at org.gradle.workers.internal.DefaultWorkerExecutor.lambda$submitWork$0(DefaultWorkerExecutor.java:174)
	at java.base/java.util.concurrent.FutureTask.run(FutureTask.java:264)
	at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner.runExecution(DefaultConditionalExecutionQueue.java:194)
	at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner.access$700(DefaultConditionalExecutionQueue.java:127)
	at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner$1.run(DefaultConditionalExecutionQueue.java:169)
	at org.gradle.internal.Factories$1.create(Factories.java:31)
	at org.gradle.internal.work.DefaultWorkerLeaseService.withLocks(DefaultWorkerLeaseService.java:263)
	at org.gradle.internal.work.DefaultWorkerLeaseService.runAsWorkerThread(DefaultWorkerLeaseService.java:127)
	at org.gradle.internal.work.DefaultWorkerLeaseService.runAsWorkerThread(DefaultWorkerLeaseService.java:132)
	at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner.runBatch(DefaultConditionalExecutionQueue.java:164)
	at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner.run(DefaultConditionalExecutionQueue.java:133)
	at java.base/java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:539)
	at java.base/java.util.concurrent.FutureTask.run(FutureTask.java:264)
	at org.gradle.internal.concurrent.ExecutorPolicy$CatchAndRecordFailures.onExecute(ExecutorPolicy.java:64)
	at org.gradle.internal.concurrent.AbstractManagedExecutor$1.run(AbstractManagedExecutor.java:48)
	at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1136)
	at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:635)
	at java.base/java.lang.Thread.run(Thread.java:840)
Caused by: java.lang.AssertionError: java.lang.Exception: Could not close incremental caches in D:\sakil\mess_finder\build\video_player_android\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab
	at org.jetbrains.kotlin.com.google.common.io.Closer.close(Closer.java:218)
	at org.jetbrains.kotlin.incremental.IncrementalCachesManager.close(IncrementalCachesManager.kt:58)
	at kotlin.io.CloseableKt.closeFinally(Closeable.kt:47)
	at org.jetbrains.kotlin.incremental.IncrementalCompilerRunner.compileNonIncrementally(IncrementalCompilerRunner.kt:296)
	at org.jetbrains.kotlin.incremental.IncrementalCompilerRunner.compile(IncrementalCompilerRunner.kt:131)
	at org.jetbrains.kotlin.daemon.CompileServiceImplBase.execIncrementalCompiler(CompileServiceImpl.kt:764)
	at org.jetbrains.kotlin.daemon.CompileServiceImplBase.access$execIncrementalCompiler(CompileServiceImpl.kt:107)
	at org.jetbrains.kotlin.daemon.CompileServiceImpl.compile(CompileServiceImpl.kt:2026)
	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:77)
	at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.base/java.lang.reflect.Method.invoke(Method.java:569)
	at java.rmi/sun.rmi.server.UnicastServerRef.dispatch(UnicastServerRef.java:360)
	at java.rmi/sun.rmi.transport.Transport$1.run(Transport.java:200)
	at java.rmi/sun.rmi.transport.Transport$1.run(Transport.java:197)
	at java.base/java.security.AccessController.doPrivileged(AccessController.java:712)
	at java.rmi/sun.rmi.transport.Transport.serviceCall(Transport.java:196)
	at java.rmi/sun.rmi.transport.tcp.TCPTransport.handleMessages(TCPTransport.java:587)
	at java.rmi/sun.rmi.transport.tcp.TCPTransport$ConnectionHandler.run0(TCPTransport.java:828)
	at java.rmi/sun.rmi.transport.tcp.TCPTransport$ConnectionHandler.lambda$run$0(TCPTransport.java:705)
	at java.base/java.security.AccessController.doPrivileged(AccessController.java:399)
	at java.rmi/sun.rmi.transport.tcp.TCPTransport$ConnectionHandler.run(TCPTransport.java:704)
	... 3 more
Caused by: java.lang.Exception: Could not close incremental caches in D:\sakil\mess_finder\build\video_player_android\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab
	at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:95)
	at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.close(BasicMapsOwner.kt:53)
	at org.jetbrains.kotlin.com.google.common.io.Closer.close(Closer.java:205)
	... 24 more
	Suppressed: java.lang.IllegalArgumentException: this and base files have different roots: C:\Users\mdsak\AppData\Local\Pub\Cache\hosted\pub.dev\video_player_android-2.12.0\android\src\main\kotlin\io\flutter\plugins\videoplayer\Messages.kt and D:\sakil\mess_finder\android.
		at kotlin.io.FilesKt__UtilsKt.toRelativeString(Utils.kt:119)
		at kotlin.io.FilesKt__UtilsKt.relativeTo(Utils.kt:130)
		at org.jetbrains.kotlin.incremental.storage.RelocatableFileToPathConverter.toPath(RelocatableFileToPathConverter.kt:24)
		at org.jetbrains.kotlin.incremental.storage.FileDescriptor.save(FileToPathConverter.kt:33)
		at org.jetbrains.kotlin.incremental.storage.FileDescriptor.save(FileToPathConverter.kt:30)
		at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.doPut(PersistentMapImpl.java:446)
		at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.put(PersistentMapImpl.java:425)
		at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.put(PersistentHashMap.java:105)
		at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
		at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
		at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
		at org.jetbrains.kotlin.incremental.storage.PersistentStorageWrapper.close(PersistentStorage.kt:124)
2
		at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
		at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
		... 26 more
	Suppressed: java.lang.IllegalArgumentException: this and base files have different roots: C:\Users\mdsak\AppData\Local\Pub\Cache\hosted\pub.dev\video_player_android-2.12.0\android\src\main\kotlin\io\flutter\plugins\videoplayer\Messages.kt and D:\sakil\mess_finder\android.
		at kotlin.io.FilesKt__UtilsKt.toRelativeString(Utils.kt:119)
		at kotlin.io.FilesKt__UtilsKt.relativeTo(Utils.kt:130)
		at org.jetbrains.kotlin.incremental.storage.RelocatableFileToPathConverter.toPath(RelocatableFileToPathConverter.kt:24)
		at org.jetbrains.kotlin.incremental.storage.FileDescriptor.getHashCode(FileToPathConverter.kt:50)
		at org.jetbrains.kotlin.incremental.storage.FileDescriptor.getHashCode(FileToPathConverter.kt:30)
		at org.jetbrains.kotlin.com.intellij.util.containers.LinkedCustomHashMap.hashKey(LinkedCustomHashMap.java:112)
		at org.jetbrains.kotlin.com.intellij.util.containers.LinkedCustomHashMap.remove(LinkedCustomHashMap.java:156)
		at org.jetbrains.kotlin.com.intellij.util.containers.SLRUMap.remove(SLRUMap.java:89)
		at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.flushAppendCache(PersistentMapImpl.java:996)
		at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.doPut(PersistentMapImpl.java:454)
		at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.put(PersistentMapImpl.java:425)
		at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.put(PersistentHashMap.java:105)
		at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
		at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
		at org.jetbrains.kotlin.incremental.storage.AppendableInMemoryStorage.applyChanges(InMemoryStorage.kt:179)
		at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
		at org.jetbrains.kotlin.incremental.storage.AppendableSetBasicMap.close(BasicMap.kt:157)
2
		at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
		at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
		... 26 more
	Suppressed: java.lang.IllegalArgumentException: this and base files have different roots: C:\Users\mdsak\AppData\Local\Pub\Cache\hosted\pub.dev\video_player_android-2.12.0\android\src\main\kotlin\io\flutter\plugins\videoplayer\Messages.kt and D:\sakil\mess_finder\android.
		at kotlin.io.FilesKt__UtilsKt.toRelativeString(Utils.kt:119)
		at kotlin.io.FilesKt__UtilsKt.relativeTo(Utils.kt:130)
		at org.jetbrains.kotlin.incremental.storage.RelocatableFileToPathConverter.toPath(RelocatableFileToPathConverter.kt:24)
		at org.jetbrains.kotlin.incremental.storage.FileDescriptor.save(FileToPathConverter.kt:33)
		at org.jetbrains.kotlin.incremental.storage.FileDescriptor.save(FileToPathConverter.kt:30)
		at org.jetbrains.kotlin.incremental.storage.AppendableCollectionExternalizer.save(LazyStorage.kt:151)
		at org.jetbrains.kotlin.incremental.storage.AppendableCollectionExternalizer.save(LazyStorage.kt:142)
		at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.doPut(PersistentMapImpl.java:446)
		at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.put(PersistentMapImpl.java:425)
		at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.put(PersistentHashMap.java:105)
		at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
		at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
		at org.jetbrains.kotlin.incremental.storage.AppendableInMemoryStorage.applyChanges(InMemoryStorage.kt:179)
		at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
		at org.jetbrains.kotlin.incremental.storage.PersistentStorageWrapper.close(PersistentStorage.kt:124)
2
		at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
		at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
		... 26 more
	Suppressed: java.lang.Exception: Could not close incremental caches in D:\sakil\mess_finder\build\video_player_android\kotlin\compileDebugKotlin\cacheable\caches-jvm\lookups: id-to-file.tab, file-to-id.tab
		at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:95)
		at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.close(BasicMapsOwner.kt:53)
		at org.jetbrains.kotlin.incremental.LookupStorage.close(LookupStorage.kt:155)
		... 25 more
		Suppressed: java.lang.IllegalArgumentException: this and base files have different roots: C:\Users\mdsak\AppData\Local\Pub\Cache\hosted\pub.dev\video_player_android-2.12.0\android\src\main\kotlin\io\flutter\plugins\videoplayer\Messages.kt and D:\sakil\mess_finder\android.
			at kotlin.io.FilesKt__UtilsKt.toRelativeString(Utils.kt:119)
			at kotlin.io.FilesKt__UtilsKt.relativeTo(Utils.kt:130)
			at org.jetbrains.kotlin.incremental.storage.RelocatableFileToPathConverter.toPath(RelocatableFileToPathConverter.kt:24)
			at org.jetbrains.kotlin.incremental.storage.LegacyFileExternalizer.save(IdToFileMap.kt:51)
			at org.jetbrains.kotlin.incremental.storage.LegacyFileExternalizer.save(IdToFileMap.kt:48)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.doPut(PersistentMapImpl.java:446)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.put(PersistentMapImpl.java:425)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.put(PersistentHashMap.java:105)
			at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
			at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
			at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
			at org.jetbrains.kotlin.incremental.storage.PersistentStorageWrapper.close(PersistentStorage.kt:124)
2
			at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
			at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
			... 27 more
		Suppressed: java.lang.IllegalArgumentException: this and base files have different roots: C:\Users\mdsak\AppData\Local\Pub\Cache\hosted\pub.dev\video_player_android-2.12.0\android\src\main\kotlin\io\flutter\plugins\videoplayer\Messages.kt and D:\sakil\mess_finder\android.
			at kotlin.io.FilesKt__UtilsKt.toRelativeString(Utils.kt:119)
			at kotlin.io.FilesKt__UtilsKt.relativeTo(Utils.kt:130)
			at org.jetbrains.kotlin.incremental.storage.RelocatableFileToPathConverter.toPath(RelocatableFileToPathConverter.kt:24)
			at org.jetbrains.kotlin.incremental.storage.FileDescriptor.getHashCode(FileToPathConverter.kt:50)
			at org.jetbrains.kotlin.incremental.storage.FileDescriptor.getHashCode(FileToPathConverter.kt:30)
			at org.jetbrains.kotlin.com.intellij.util.containers.LinkedCustomHashMap.hashKey(LinkedCustomHashMap.java:112)
			at org.jetbrains.kotlin.com.intellij.util.containers.LinkedCustomHashMap.remove(LinkedCustomHashMap.java:156)
			at org.jetbrains.kotlin.com.intellij.util.containers.SLRUMap.remove(SLRUMap.java:89)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.flushAppendCache(PersistentMapImpl.java:996)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.doPut(PersistentMapImpl.java:454)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.put(PersistentMapImpl.java:425)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.put(PersistentHashMap.java:105)
			at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
			at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
			at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
			at org.jetbrains.kotlin.incremental.storage.PersistentStorageWrapper.close(PersistentStorage.kt:124)
2
			at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
			at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
			... 27 more
	Suppressed: java.lang.Exception: Could not close incremental caches in D:\sakil\mess_finder\build\video_player_android\kotlin\compileDebugKotlin\cacheable\caches-jvm\inputs: source-to-output.tab
		... 27 more
		Suppressed: java.lang.IllegalArgumentException: this and base files have different roots: C:\Users\mdsak\AppData\Local\Pub\Cache\hosted\pub.dev\video_player_android-2.12.0\android\src\main\kotlin\io\flutter\plugins\videoplayer\Messages.kt and D:\sakil\mess_finder\android.
			at kotlin.io.FilesKt__UtilsKt.toRelativeString(Utils.kt:119)
			at kotlin.io.FilesKt__UtilsKt.relativeTo(Utils.kt:130)
			at org.jetbrains.kotlin.incremental.storage.RelocatableFileToPathConverter.toPath(RelocatableFileToPathConverter.kt:24)
			at org.jetbrains.kotlin.incremental.storage.FileDescriptor.getHashCode(FileToPathConverter.kt:50)
			at org.jetbrains.kotlin.incremental.storage.FileDescriptor.getHashCode(FileToPathConverter.kt:30)
			at org.jetbrains.kotlin.com.intellij.util.containers.LinkedCustomHashMap.hashKey(LinkedCustomHashMap.java:112)
			at org.jetbrains.kotlin.com.intellij.util.containers.LinkedCustomHashMap.remove(LinkedCustomHashMap.java:156)
			at org.jetbrains.kotlin.com.intellij.util.containers.SLRUMap.remove(SLRUMap.java:89)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.flushAppendCache(PersistentMapImpl.java:996)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.doPut(PersistentMapImpl.java:454)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.put(PersistentMapImpl.java:425)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.put(PersistentHashMap.java:105)
			at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
			at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
			at org.jetbrains.kotlin.incremental.storage.AppendableInMemoryStorage.applyChanges(InMemoryStorage.kt:179)
			at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
			at org.jetbrains.kotlin.incremental.storage.AppendableSetBasicMap.close(BasicMap.kt:157)
2
			at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
			at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
			... 26 more
e: Daemon compilation failed
java.lang.Exception
	at org.jetbrains.kotlin.daemon.common.CompileService$CallResult$Error.get(CompileService.kt:69)
	at org.jetbrains.kotlin.daemon.common.CompileService$CallResult$Error.get(CompileService.kt:65)
	at org.jetbrains.kotlin.buildtools.internal.jvm.operations.JvmCompilationOperationImpl.compileWithDaemon(JvmCompilationOperationImpl.kt:303)
	at org.jetbrains.kotlin.buildtools.internal.jvm.operations.JvmCompilationOperationImpl.executeCancellableImpl(JvmCompilationOperationImpl.kt:152)
	at org.jetbrains.kotlin.buildtools.internal.jvm.operations.JvmCompilationOperationImpl.executeCancellableImpl(JvmCompilationOperationImpl.kt:69)
	at org.jetbrains.kotlin.buildtools.internal.CancellableBuildOperationImpl.executeImpl(CancellableBuildOperationImpl.kt:58)
	at org.jetbrains.kotlin.buildtools.internal.BuildOperationImpl.execute(BuildOperationImpl.kt:34)
	at org.jetbrains.kotlin.buildtools.internal.KotlinToolchainsImpl$BuildSessionImpl.executeOperation$lambda$1(KotlinToolchainsImpl.kt:70)
	at org.jetbrains.kotlin.buildtools.internal.KotlinToolchainsImpl$BuildSessionImpl.executeOperation(KotlinToolchainsImpl.kt:74)
	at org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork.performCompilation(BuildToolsApiCompilationWork.kt:172)
	at org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork.compileInDaemon(BuildToolsApiCompilationWork.kt:244)
	at org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork.execute(BuildToolsApiCompilationWork.kt:285)
	at org.gradle.workers.internal.DefaultWorkerServer.execute(DefaultWorkerServer.java:63)
	at org.gradle.workers.internal.NoIsolationWorkerFactory$1$1.create(NoIsolationWorkerFactory.java:66)
	at org.gradle.workers.internal.NoIsolationWorkerFactory$1$1.create(NoIsolationWorkerFactory.java:62)
	at org.gradle.internal.classloader.ClassLoaderUtils.executeInClassloader(ClassLoaderUtils.java:100)
	at org.gradle.workers.internal.NoIsolationWorkerFactory$1.lambda$execute$0(NoIsolationWorkerFactory.java:62)
	at org.gradle.workers.internal.AbstractWorker$1.call(AbstractWorker.java:44)
	at org.gradle.workers.internal.AbstractWorker$1.call(AbstractWorker.java:41)
	at org.gradle.internal.operations.DefaultBuildOperationRunner$CallableBuildOperationWorker.execute(DefaultBuildOperationRunner.java:209)
	at org.gradle.internal.operations.DefaultBuildOperationRunner$CallableBuildOperationWorker.execute(DefaultBuildOperationRunner.java:204)
	at org.gradle.internal.operations.DefaultBuildOperationRunner$2.execute(DefaultBuildOperationRunner.java:66)
	at org.gradle.internal.operations.DefaultBuildOperationRunner$2.execute(DefaultBuildOperationRunner.java:59)
	at org.gradle.internal.operations.DefaultBuildOperationRunner.execute(DefaultBuildOperationRunner.java:166)
	at org.gradle.internal.operations.DefaultBuildOperationRunner.execute(DefaultBuildOperationRunner.java:59)
	at org.gradle.internal.operations.DefaultBuildOperationRunner.call(DefaultBuildOperationRunner.java:53)
	at org.gradle.workers.internal.AbstractWorker.executeWrappedInBuildOperation(AbstractWorker.java:41)
	at org.gradle.workers.internal.NoIsolationWorkerFactory$1.execute(NoIsolationWorkerFactory.java:59)
	at org.gradle.workers.internal.DefaultWorkerExecutor.lambda$submitWork$0(DefaultWorkerExecutor.java:174)
	at java.base/java.util.concurrent.FutureTask.run(FutureTask.java:264)
	at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner.runExecution(DefaultConditionalExecutionQueue.java:194)
	at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner.access$700(DefaultConditionalExecutionQueue.java:127)
	at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner$1.run(DefaultConditionalExecutionQueue.java:169)
	at org.gradle.internal.Factories$1.create(Factories.java:31)
	at org.gradle.internal.work.DefaultWorkerLeaseService.withLocks(DefaultWorkerLeaseService.java:263)
	at org.gradle.internal.work.DefaultWorkerLeaseService.runAsWorkerThread(DefaultWorkerLeaseService.java:127)
	at org.gradle.internal.work.DefaultWorkerLeaseService.runAsWorkerThread(DefaultWorkerLeaseService.java:132)
	at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner.runBatch(DefaultConditionalExecutionQueue.java:164)
	at org.gradle.internal.work.DefaultConditionalExecutionQueue$ExecutionRunner.run(DefaultConditionalExecutionQueue.java:133)
	at java.base/java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:539)
	at java.base/java.util.concurrent.FutureTask.run(FutureTask.java:264)
	at org.gradle.internal.concurrent.ExecutorPolicy$CatchAndRecordFailures.onExecute(ExecutorPolicy.java:64)
	at org.gradle.internal.concurrent.AbstractManagedExecutor$1.run(AbstractManagedExecutor.java:48)
	at java.base/java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1136)
	at java.base/java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:635)
	at java.base/java.lang.Thread.run(Thread.java:840)
Caused by: java.lang.AssertionError: java.lang.Exception: Could not close incremental caches in D:\sakil\mess_finder\build\google_maps_flutter_android\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab
	at org.jetbrains.kotlin.com.google.common.io.Closer.close(Closer.java:218)
	at org.jetbrains.kotlin.incremental.IncrementalCachesManager.close(IncrementalCachesManager.kt:58)
	at kotlin.io.CloseableKt.closeFinally(Closeable.kt:47)
	at org.jetbrains.kotlin.incremental.IncrementalCompilerRunner.compileNonIncrementally(IncrementalCompilerRunner.kt:296)
	at org.jetbrains.kotlin.incremental.IncrementalCompilerRunner.compile(IncrementalCompilerRunner.kt:131)
	at org.jetbrains.kotlin.daemon.CompileServiceImplBase.execIncrementalCompiler(CompileServiceImpl.kt:764)
	at org.jetbrains.kotlin.daemon.CompileServiceImplBase.access$execIncrementalCompiler(CompileServiceImpl.kt:107)
	at org.jetbrains.kotlin.daemon.CompileServiceImpl.compile(CompileServiceImpl.kt:2026)
	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
	at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:77)
	at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
	at java.base/java.lang.reflect.Method.invoke(Method.java:569)
	at java.rmi/sun.rmi.server.UnicastServerRef.dispatch(UnicastServerRef.java:360)
	at java.rmi/sun.rmi.transport.Transport$1.run(Transport.java:200)
	at java.rmi/sun.rmi.transport.Transport$1.run(Transport.java:197)
	at java.base/java.security.AccessController.doPrivileged(AccessController.java:712)
	at java.rmi/sun.rmi.transport.Transport.serviceCall(Transport.java:196)
	at java.rmi/sun.rmi.transport.tcp.TCPTransport.handleMessages(TCPTransport.java:587)
	at java.rmi/sun.rmi.transport.tcp.TCPTransport$ConnectionHandler.run0(TCPTransport.java:828)
	at java.rmi/sun.rmi.transport.tcp.TCPTransport$ConnectionHandler.lambda$run$0(TCPTransport.java:705)
	at java.base/java.security.AccessController.doPrivileged(AccessController.java:399)
	at java.rmi/sun.rmi.transport.tcp.TCPTransport$ConnectionHandler.run(TCPTransport.java:704)
	... 3 more
Caused by: java.lang.Exception: Could not close incremental caches in D:\sakil\mess_finder\build\google_maps_flutter_android\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab
	at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:95)
	at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.close(BasicMapsOwner.kt:53)
	at org.jetbrains.kotlin.com.google.common.io.Closer.close(Closer.java:205)
	... 24 more
	Suppressed: java.lang.IllegalArgumentException: this and base files have different roots: C:\Users\mdsak\AppData\Local\Pub\Cache\hosted\pub.dev\google_maps_flutter_android-2.19.12\android\src\main\kotlin\io\flutter\plugins\googlemaps\Messages.kt and D:\sakil\mess_finder\android.
		at kotlin.io.FilesKt__UtilsKt.toRelativeString(Utils.kt:119)
		at kotlin.io.FilesKt__UtilsKt.relativeTo(Utils.kt:130)
		at org.jetbrains.kotlin.incremental.storage.RelocatableFileToPathConverter.toPath(RelocatableFileToPathConverter.kt:24)
		at org.jetbrains.kotlin.incremental.storage.FileDescriptor.save(FileToPathConverter.kt:33)
		at org.jetbrains.kotlin.incremental.storage.FileDescriptor.save(FileToPathConverter.kt:30)
		at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.doPut(PersistentMapImpl.java:446)
		at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.put(PersistentMapImpl.java:425)
		at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.put(PersistentHashMap.java:105)
		at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
		at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
		at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
		at org.jetbrains.kotlin.incremental.storage.PersistentStorageWrapper.close(PersistentStorage.kt:124)
2
		at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
		at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
		... 26 more
	Suppressed: java.lang.IllegalArgumentException: this and base files have different roots: C:\Users\mdsak\AppData\Local\Pub\Cache\hosted\pub.dev\google_maps_flutter_android-2.19.12\android\src\main\kotlin\io\flutter\plugins\googlemaps\Messages.kt and D:\sakil\mess_finder\android.
		at kotlin.io.FilesKt__UtilsKt.toRelativeString(Utils.kt:119)
		at kotlin.io.FilesKt__UtilsKt.relativeTo(Utils.kt:130)
		at org.jetbrains.kotlin.incremental.storage.RelocatableFileToPathConverter.toPath(RelocatableFileToPathConverter.kt:24)
		at org.jetbrains.kotlin.incremental.storage.FileDescriptor.getHashCode(FileToPathConverter.kt:50)
		at org.jetbrains.kotlin.incremental.storage.FileDescriptor.getHashCode(FileToPathConverter.kt:30)
		at org.jetbrains.kotlin.com.intellij.util.containers.LinkedCustomHashMap.hashKey(LinkedCustomHashMap.java:112)
		at org.jetbrains.kotlin.com.intellij.util.containers.LinkedCustomHashMap.remove(LinkedCustomHashMap.java:156)
		at org.jetbrains.kotlin.com.intellij.util.containers.SLRUMap.remove(SLRUMap.java:89)
		at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.flushAppendCache(PersistentMapImpl.java:996)
		at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.doPut(PersistentMapImpl.java:454)
		at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.put(PersistentMapImpl.java:425)
		at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.put(PersistentHashMap.java:105)
		at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
		at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
		at org.jetbrains.kotlin.incremental.storage.AppendableInMemoryStorage.applyChanges(InMemoryStorage.kt:179)
		at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
		at org.jetbrains.kotlin.incremental.storage.AppendableSetBasicMap.close(BasicMap.kt:157)
2
		at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
		at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
		... 26 more
	Suppressed: java.lang.IllegalArgumentException: this and base files have different roots: C:\Users\mdsak\AppData\Local\Pub\Cache\hosted\pub.dev\google_maps_flutter_android-2.19.12\android\src\main\kotlin\io\flutter\plugins\googlemaps\Messages.kt and D:\sakil\mess_finder\android.
		at kotlin.io.FilesKt__UtilsKt.toRelativeString(Utils.kt:119)
		at kotlin.io.FilesKt__UtilsKt.relativeTo(Utils.kt:130)
		at org.jetbrains.kotlin.incremental.storage.RelocatableFileToPathConverter.toPath(RelocatableFileToPathConverter.kt:24)
		at org.jetbrains.kotlin.incremental.storage.FileDescriptor.save(FileToPathConverter.kt:33)
		at org.jetbrains.kotlin.incremental.storage.FileDescriptor.save(FileToPathConverter.kt:30)
		at org.jetbrains.kotlin.incremental.storage.AppendableCollectionExternalizer.save(LazyStorage.kt:151)
		at org.jetbrains.kotlin.incremental.storage.AppendableCollectionExternalizer.save(LazyStorage.kt:142)
		at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.doPut(PersistentMapImpl.java:446)
		at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.put(PersistentMapImpl.java:425)
		at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.put(PersistentHashMap.java:105)
		at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
		at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
		at org.jetbrains.kotlin.incremental.storage.AppendableInMemoryStorage.applyChanges(InMemoryStorage.kt:179)
		at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
		at org.jetbrains.kotlin.incremental.storage.PersistentStorageWrapper.close(PersistentStorage.kt:124)
2
		at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
		at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
		... 26 more
	Suppressed: java.lang.Exception: Could not close incremental caches in D:\sakil\mess_finder\build\google_maps_flutter_android\kotlin\compileDebugKotlin\cacheable\caches-jvm\lookups: id-to-file.tab, file-to-id.tab
		at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:95)
		at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.close(BasicMapsOwner.kt:53)
		at org.jetbrains.kotlin.incremental.LookupStorage.close(LookupStorage.kt:155)
		... 25 more
		Suppressed: java.lang.IllegalArgumentException: this and base files have different roots: C:\Users\mdsak\AppData\Local\Pub\Cache\hosted\pub.dev\google_maps_flutter_android-2.19.12\android\src\main\kotlin\io\flutter\plugins\googlemaps\Messages.kt and D:\sakil\mess_finder\android.
			at kotlin.io.FilesKt__UtilsKt.toRelativeString(Utils.kt:119)
			at kotlin.io.FilesKt__UtilsKt.relativeTo(Utils.kt:130)
			at org.jetbrains.kotlin.incremental.storage.RelocatableFileToPathConverter.toPath(RelocatableFileToPathConverter.kt:24)
			at org.jetbrains.kotlin.incremental.storage.LegacyFileExternalizer.save(IdToFileMap.kt:51)
			at org.jetbrains.kotlin.incremental.storage.LegacyFileExternalizer.save(IdToFileMap.kt:48)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.doPut(PersistentMapImpl.java:446)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.put(PersistentMapImpl.java:425)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.put(PersistentHashMap.java:105)
			at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
			at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
			at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
			at org.jetbrains.kotlin.incremental.storage.PersistentStorageWrapper.close(PersistentStorage.kt:124)
2
			at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
			at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
			... 27 more
		Suppressed: java.lang.IllegalArgumentException: this and base files have different roots: C:\Users\mdsak\AppData\Local\Pub\Cache\hosted\pub.dev\google_maps_flutter_android-2.19.12\android\src\main\kotlin\io\flutter\plugins\googlemaps\Messages.kt and D:\sakil\mess_finder\android.
			at kotlin.io.FilesKt__UtilsKt.toRelativeString(Utils.kt:119)
			at kotlin.io.FilesKt__UtilsKt.relativeTo(Utils.kt:130)
			at org.jetbrains.kotlin.incremental.storage.RelocatableFileToPathConverter.toPath(RelocatableFileToPathConverter.kt:24)
			at org.jetbrains.kotlin.incremental.storage.FileDescriptor.getHashCode(FileToPathConverter.kt:50)
			at org.jetbrains.kotlin.incremental.storage.FileDescriptor.getHashCode(FileToPathConverter.kt:30)
			at org.jetbrains.kotlin.com.intellij.util.containers.LinkedCustomHashMap.hashKey(LinkedCustomHashMap.java:112)
			at org.jetbrains.kotlin.com.intellij.util.containers.LinkedCustomHashMap.remove(LinkedCustomHashMap.java:156)
			at org.jetbrains.kotlin.com.intellij.util.containers.SLRUMap.remove(SLRUMap.java:89)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.flushAppendCache(PersistentMapImpl.java:996)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.doPut(PersistentMapImpl.java:454)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.put(PersistentMapImpl.java:425)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.put(PersistentHashMap.java:105)
			at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
			at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
			at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
			at org.jetbrains.kotlin.incremental.storage.PersistentStorageWrapper.close(PersistentStorage.kt:124)
2
			at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
			at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
			... 27 more
	Suppressed: java.lang.Exception: Could not close incremental caches in D:\sakil\mess_finder\build\google_maps_flutter_android\kotlin\compileDebugKotlin\cacheable\caches-jvm\inputs: source-to-output.tab
		... 27 more
		Suppressed: java.lang.IllegalArgumentException: this and base files have different roots: C:\Users\mdsak\AppData\Local\Pub\Cache\hosted\pub.dev\google_maps_flutter_android-2.19.12\android\src\main\kotlin\io\flutter\plugins\googlemaps\Messages.kt and D:\sakil\mess_finder\android.
			at kotlin.io.FilesKt__UtilsKt.toRelativeString(Utils.kt:119)
			at kotlin.io.FilesKt__UtilsKt.relativeTo(Utils.kt:130)
			at org.jetbrains.kotlin.incremental.storage.RelocatableFileToPathConverter.toPath(RelocatableFileToPathConverter.kt:24)
			at org.jetbrains.kotlin.incremental.storage.FileDescriptor.getHashCode(FileToPathConverter.kt:50)
			at org.jetbrains.kotlin.incremental.storage.FileDescriptor.getHashCode(FileToPathConverter.kt:30)
			at org.jetbrains.kotlin.com.intellij.util.containers.LinkedCustomHashMap.hashKey(LinkedCustomHashMap.java:112)
			at org.jetbrains.kotlin.com.intellij.util.containers.LinkedCustomHashMap.remove(LinkedCustomHashMap.java:156)
			at org.jetbrains.kotlin.com.intellij.util.containers.SLRUMap.remove(SLRUMap.java:89)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.flushAppendCache(PersistentMapImpl.java:996)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.doPut(PersistentMapImpl.java:454)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentMapImpl.put(PersistentMapImpl.java:425)
			at org.jetbrains.kotlin.com.intellij.util.io.PersistentHashMap.put(PersistentHashMap.java:105)
			at org.jetbrains.kotlin.incremental.storage.LazyStorage.set(LazyStorage.kt:80)
			at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.applyChanges(InMemoryStorage.kt:108)
			at org.jetbrains.kotlin.incremental.storage.AppendableInMemoryStorage.applyChanges(InMemoryStorage.kt:179)
			at org.jetbrains.kotlin.incremental.storage.InMemoryStorage.close(InMemoryStorage.kt:136)
			at org.jetbrains.kotlin.incremental.storage.AppendableSetBasicMap.close(BasicMap.kt:157)
2
			at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner$close$1.invoke(BasicMapsOwner.kt:53)
			at org.jetbrains.kotlin.incremental.storage.BasicMapsOwner.forEachMapSafe(BasicMapsOwner.kt:87)
			... 26 more

FAILURE: Build completed with 8 failures.

1: Task failed with an exception.
-----------
* What went wrong:
Execution failed for task ':package_info_plus:compileDebugKotlin'.
> A failure occurred while executing org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork
   > java.lang.Exception: Could not close incremental caches in D:\sakil\mess_finder\build\package_info_plus\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.
==============================================================================

2: Task failed with an exception.
-----------
* What went wrong:
Execution failed for task ':flutter_image_compress_common:compileDebugKotlin'.
> A failure occurred while executing org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork
   > java.lang.Exception: Could not close incremental caches in D:\sakil\mess_finder\build\flutter_image_compress_common\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.
==============================================================================

3: Task failed with an exception.
-----------
* What went wrong:
Execution failed for task ':url_launcher_android:compileDebugKotlin'.
> A failure occurred while executing org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork
   > java.lang.Exception: Could not close incremental caches in D:\sakil\mess_finder\build\url_launcher_android\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.
==============================================================================

4: Task failed with an exception.
-----------
* What went wrong:
Execution failed for task ':image_picker_android:compileDebugKotlin'.
> A failure occurred while executing org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork
   > java.lang.Exception: Could not close incremental caches in D:\sakil\mess_finder\build\image_picker_android\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.
==============================================================================

5: Task failed with an exception.
-----------
* What went wrong:
Execution failed for task ':share_plus:compileDebugKotlin'.
> A failure occurred while executing org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork
   > java.lang.Exception: Could not close incremental caches in D:\sakil\mess_finder\build\share_plus\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.
==============================================================================

6: Task failed with an exception.
-----------
* What went wrong:
Execution failed for task ':video_player_android:compileDebugKotlin'.
> A failure occurred while executing org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork
   > java.lang.Exception: Could not close incremental caches in D:\sakil\mess_finder\build\video_player_android\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.
==============================================================================

7: Task failed with an exception.
-----------
* What went wrong:
Execution failed for task ':shared_preferences_android:compileDebugKotlin'.
> A failure occurred while executing org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork
   > java.lang.Exception: Could not close incremental caches in D:\sakil\mess_finder\build\shared_preferences_android\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.
==============================================================================

8: Task failed with an exception.
-----------
* What went wrong:
Execution failed for task ':google_maps_flutter_android:compileDebugKotlin'.
> A failure occurred while executing org.jetbrains.kotlin.compilerRunner.btapi.BuildToolsApiCompilationWork
   > java.lang.Exception: Could not close incremental caches in D:\sakil\mess_finder\build\google_maps_flutter_android\kotlin\compileDebugKotlin\cacheable\caches-jvm\jvm\kotlin: class-fq-name-to-source.tab, source-to-classes.tab, internal-name-to-source.tab

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.
==============================================================================

BUILD FAILED in 2m 12s
Error: Gradle task assembleDebug failed with exit code 1

Exited (1).