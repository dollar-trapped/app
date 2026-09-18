# Room 2.2.x creates WorkManager's generated database through reflection.
# Its consumer rule keeps the class name, but R8 full mode can remove the
# no-argument constructor. Keep precisely the reflective entry point.
-keep class androidx.work.impl.WorkDatabase_Impl {
    public <init>();
}
